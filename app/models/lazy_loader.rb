class LazyLoader
    include ActiveModel::Model
    require "selenium-webdriver"
    
    def self.load_lazy(url)
        Selenium::WebDriver::Chrome::Service.driver_path= ['CHROME_DRIVER_PATH'] #wslの場合、Cドライブ下にChome Driverを配置
        option = Selenium::WebDriver::Chrome::Options.new
        option.add_argument('--headless')
        driver = Selenium::WebDriver.for :chrome, options: option
        wait = Selenium::WebDriver::Wait.new(:timeout => 30)
        driver.navigate.to url

        lazyloads = Array.new #読まれていない画像
        wait.until {lazyloads = driver.find_elements(:class=> "lazyload")}

        lazyloads.each do |element|
            driver.execute_script("window.scroll(#{element.location.x},#{element.location.y});")
        end

        sleep 0.5
        body = driver.page_source
        driver.quit()
        return body
    end
end
