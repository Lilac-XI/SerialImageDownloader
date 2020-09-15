class HomeController < ApplicationController
    require "open-uri"
    require "rmagick"
    require "./app/lib/image_downloader"
    include SavePDF
    include URLChecker
    require "benchmark"

    def home
        @donwload = true
    end

    def create
        url = params[:download_link]
        body = OpenURI.open_uri(url).read
        if body.include?("lazyload")
            puts "lazy start"
            result = Benchmark.realtime do
                body = LazyLoader.load_lazy(url)
            end
            puts "remove time #{result}"
        end
        
        image_tags = body.scan(/<img.*?>/)

        image_links = shape_image_tags(image_tags)
        similar_links = split_similars(image_links)

        targets =  similar_links.max
        
        title = Magick::Image.read(targets[0])[0]
        image_downloader = ImageDownloader.new(title.x_resolution,title.y_resolution)
        
        result = Benchmark.realtime do
            puts "start"
            image_files = image_downloader.create_image_files(targets)

            puts "save pdf"
            save_pdf(image_files, "results/result.pdf")
            GC.start
            FileUtils.rm(Dir.glob("/tmp/magick-*"))
        end
        puts "save pdf time #{result}"
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