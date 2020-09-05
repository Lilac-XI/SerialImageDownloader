class HomeController < ApplicationController
    require "open-uri"
    require "trigram"
    require "rmagick"
    require "combine_pdf"
    require "fileutils"
    def home
        @donwload = true
    end

    def edit

        url = params[:download_link]

        imagetags = OpenURI.open_uri(url).read.scan(/<img.*?>/)
        imagelinks = Array.new

        imagetags.each_with_index do |tag, i|
            imagelinks[i] = tag.scan(/src="http.*?"/).join
            imagelinks[i].slice!(/src="/)
            imagelinks[i].slice!(/"/)
        end
        imagelinks.uniq!

        similars = Array.new(imagelinks.size-1)
        imagelinks.each_with_index do |link,i|
            if i < similars.size
                similars[i] = Trigram.compare link, imagelinks[i+1]
            end
        end
        l = 0
        sl = 0
        similar_links = Array.new
        similars.each_with_index do |num,i|
            if i >= l
                if num < 0.7
                    similar_links[sl] = imagelinks[l..i]
                    sl = sl+1
                    l = i+1
                end
            end
        end
        similar_links.delete_if do |links|
            links.size < 7
        end
        
        targets =  similar_links.max
        pdfs = Array.new
        num = 0
        image_files = Magick::ImageList.new()
        pdfs = Array.new
        puts "start"
        targets.each_with_index do |link,i|
            puts link
            begin
                image = Magick::Image.read(link)[0]
                image_files.push image
                if i != 0 && (i % 50 == 0 || i == targets.size)
                    image_files.write("result/result#{num}.pdf")
                    pdfs[num] = "result/result#{num}.pdf"
                    num = num + 1
                    image_files = Magick::ImageList.new()
                    GC.start
                end
            rescue => e
                puts "エラー: #{e}"
            end
        end
        puts "combine pdf"
        result = CombinePDF.new
        puts pdfs
        pdfs.each do |pdf_link|
            result << CombinePDF.load(pdf_link)
        end
        result.save ("result.pdf")
        Dir.chdir "result"
        FileUtils.rm(Dir.glob('*.*'))
    end

    def download
        filepath = Rails.root.join("","result.pdf")
        puts filepath
        filename = "#{Date.today.to_time.strftime("%y-%m-%d-%H-%M-%S")}.pdf"
        stat = File::stat(filepath)
        send_file(filepath,filename: filename, length: stat.size)
    end
end