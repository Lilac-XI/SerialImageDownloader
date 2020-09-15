module SavePDF extend ActiveSupport::Concern
    require "rmagick"

    def save_pdf(image_files, path)
        image_files.write(path)
        GC.start
        FileUtils.rm(Dir.glob("/tmp/magick-*"))
    end

end