class ImageDownloader
    require "rmagick"

    def initialize(x_resolution, y_resolution, limit = 50)
        @x_resolution = x_resolution
        @y_resolution = y_resolution
        @limit = limit
    end

    def download_image(url)
        image = Magick::Image.read(url)[0]
        if image.x_resolution != @x_resolution || image.y_resolution != @y_resolution
            image.x_resolution = @x_resolution
            image.y_resolution = @y_resolution
        end
        return image
    end

    def under_limit_download(targets)
        image_files = Magick::ImageList.new()
        targets.each do |link|
            begin
                image = download_image(link)
                puts link
                image_files.push image
            rescue => e
                puts "エラー: #{e}"
            end
        end
        return image_files
    end

    def over_limit_download(targets)
    end
end