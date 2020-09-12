class ImageDownloader
    require "rmagick"

    def initialize(x_resolution, y_resolution)
        @x_resolution = x_resolution
        @y_resolution = y_resolution
    end

    def download_image(url)
        image = Magick::Image.read(url)[0]
        if image.x_resolution != @x_resolution || image.y_resolution != @y_resolution
            puts "#{i} resize"
            image.x_resolution = @x_resolution
            image.y_resolution = @y_resolution
        end
        return image
    end
end