class ImageDownloader
    require "rmagick"
    require "parallel"

    def initialize(x_resolution, y_resolution, limit = 50)
        @x_resolution = x_resolution
        @y_resolution = y_resolution
        @limit = limit
    end

    def download_image(url)
        image = nil
        begin
            image = Magick::Image.read(url)[0]
            if image.x_resolution != @x_resolution || image.y_resolution != @y_resolution
                image.x_resolution = @x_resolution
                image.y_resolution = @y_resolution
            end
        rescue => e
            puts e
        end

        return image
    end

    def create_image_files(targets)
        
        image_files_tmp = Parallel.map_with_index(targets, in_proccess: 10) do |link,i|
            puts link
            image = download_image(link)
        end

        image_files = Magick::ImageList.new()
        image_files_tmp.each do |image|
            image_files << image
        end

        return image_files
    end
end