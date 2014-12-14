require 'nokogiri'
require 'open-uri'
require 'chartkick'


class StatsController < ActionController::Base
  def input
    @an = Time.now.year
    @zi = Time.now.day
    @luna = Time.now.month
    render "input"
  end

  def aplicarea_handicapului (cota, diferenta_gameuri)
    case cota
    when 0..1.10
      diferenta_gameuri - 6.5
    when 0..1.22
      diferenta_gameuri - 5.5
    when 0..1.33
      diferenta_gameuri - 4.5
    when 0..1.50
      diferenta_gameuri - 3.5
    when 0..1.61
      diferenta_gameuri - 2.5
    when 0..1.72
      diferenta_gameuri - 1.5
    when 0..1.84
      diferenta_gameuri - 0.5
    when 0..1.96
      diferenta_gameuri + 0.5
    when 0..2.10
      diferenta_gameuri + 1.5
    when 0..2.37
      diferenta_gameuri + 2.5
    when 0..3.00
      diferenta_gameuri + 3.5
    when 0..3.75
      diferenta_gameuri + 4.5
    when 0..5.50
      diferenta_gameuri + 5.5
    else
      diferenta_gameuri + 6.5
    end
  end

  def calcstats
    @nr_meciuri_cautate = params[:nr_meciuri_cautate].to_i
    zi = params[:zi_input].to_i
    luna = params[:luna_input].to_i
    an = params[:an_input].to_i
    x = 0
    cnt = 0
    tip_turneu='atp'
      lista_nume_TE = Array.new
      lista_nume = Array.new
      while x < 2
        url = "http://www.tennisexplorer.com/matches/?type=#{tip_turneu}-single&year=#{an}&month=#{luna}&day=#{zi}"
        data = Nokogiri::HTML(open(url))
        tabel = data.css('.result')
          tabel.css('.t-name a').map do |link|
            if link['href'][1..6] == "player"
              lista_nume_TE << link['href']
            end
            if /[a-zA-Z]/ === link.text[0] and link.text[-1] == "."
              lista_nume << link.text
            end
          end
      x += 1
      tip_turneu = 'wta'
      end
    @date_elem = Hash.new{|hsh,key| hsh[key] = [] }
    data_ultim_meci = ""
    an_stop = 0
    v=0
    nr_total_meciuri = 1
    lista_nume_TE.map do |x|
      count = 0
      an=Time.now.year
      statistica = Array.new
      while an > an_stop - 1 and count < @nr_meciuri_cautate
        url = "http://www.tennisexplorer.com#{x}?annual=#{an}"
        data = Nokogiri::HTML(open(url))
        tabel = data.css("div#matches-#{an}-1-data")
        an_stop = data.at_css('#balMenu-1-data tbody').text.scan(/\b\d{4}\b/).last.to_i
        an -= 1
        #nume_jucator = data.css(".plDetail h3").text.split(" ")[0]
        nume_turneu = ""
        tabel.css('tr').map do |meci|
          break if count == @nr_meciuri_cautate
          if meci["class"] == "head flags"
            nume_turneu = meci.text.strip.split("\n")[0][2..-1]
          elsif nume_turneu != "Int. Premier Tennis League"
            suprafata = meci.to_s.scan(Regexp.union(/grass/, /clay/, /hard/, /indoors/))
            meci = meci.text.to_s.delete ("\n" and "\t")
            meci_arr = meci.split("\n")
            cond = false
            unless meci_arr[5].nil?
              scor_fara_sup = meci_arr[5].gsub(/6\d+/,"6")
              meci_intreg1 = scor_fara_sup.gsub("7-5","-").gsub("5-7","-").scan("-").length
              meci_intreg2 = scor_fara_sup.gsub("7-5","6").gsub("5-7","6").scan("6").length
              if meci_intreg1 != 1 and meci_intreg1 == meci_intreg2
                cond = true
              end
            end
            #gs_true = five_sets.include?(nume_turneu)
            count += 1
            if meci_arr[6].to_f != 0.0 and meci_arr[5] != "" and cond
              if meci_arr[3].split(' -')[0] == lista_nume[v]
                castigator = true
              else
                castigator = false
              end
              if castigator == true
                cota = meci_arr[6].to_f
              else
                cota = meci_arr[7].to_f
              end
              scor = scor_fara_sup.dup
              diferenta_gameuri = eval(scor.gsub(",","+"))
              if !castigator
                diferenta_gameuri = -diferenta_gameuri
              end
              z = aplicarea_handicapului(cota, diferenta_gameuri)
              data_ultim_meci = meci_arr[1] + "#{an+1}"
              if z > 0
                statistica << 1
              elsif z < 0
                statistica << -1
              end
            else
              statistica << 0
            end
          end
        end
      end
      @date_elem[lista_nume[v]] << statistica
      @date_elem[lista_nume[v]] << data_ultim_meci
      v +=1
    end
    render 'result'
  end
  def graf

  end
end
