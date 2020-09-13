module SavePDF extend ActiveSupport::Concern
    require "combine_pdf"

    def combine(path_list)
        pdf = CombinePDF.new
        path_list.each do |pdf_path|
            pdf << CombinePDF.load(pdf_path)
        end
        pdf.save ("results/result.pdf")
    end

end