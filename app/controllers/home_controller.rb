class HomeController < ApplicationController
    require "open-uri"
    require "trigram"
    require "rmagick"
    require "./app/lib/image_downloader"
    include SavePDF
    include URLChecker

    def home
        @donwload = true
    end

    def create
        url = params[:download_link]
        image_tags = OpenURI.open_uri(url).read.scan(/<img.*?>/)

        image_links = shape_image_tags(image_tags)
        image_links = remove_died_url(image_links)
        similar_links = split_similars(image_links)

        targets =  similar_links.max
        
        image_files = Magick::ImageList.new()
        title = Magick::Image.read(targets[0])[0]
        image_downloader = ImageDownloader.new(title.x_resolution,title.y_resolution)
        puts "start"
        if targets.size > 50
            puts "Over 50 page mode."
            path_list = Array.new
            num = 0
            targets.each_with_index do |link,i|
                begin
                    image = image_downloader.download_image(link)
                    puts link
                    image_files.push image
                    if (i != 0 && (i % 50 == 0)) || (i > 50 && i == targets.size-1)
                        image_files.write("results/result#{num}.pdf")
                        path_list[num] = "results/result#{num}.pdf"
                        puts "save results/result#{num}.pdf"
                        num = num + 1
                        image_files = Magick::ImageList.new()
                        GC.start
                        FileUtils.rm(Dir.glob("/tmp/magick-*"))
                    end
                rescue => e
                    puts "エラー: #{e}"
                end
            end
            puts "combine pdf"
            combine(path_list)
            GC.start
        else
            puts "Under 50 page mode."
            image_files = image_downloader.under_limit_download(targets)
            puts "save pdf"
            image_files.write("results/result.pdf")
            GC.start
            FileUtils.rm(Dir.glob("/tmp/magick-*"))
        end
        redirect_to action: :ready
    end

    def ready
    end

    def download
        filepath = Rails.root.join("results","result.pdf")
        puts filepath
        filename = "#{Date.today.to_time.strftime("%y-%m-%d-%h-%m-%s")}.pdf"
        stat = File::stat(filepath)
        puts stat.size
        send_file(filepath, filename: filename, length: stat.size)
    end
end