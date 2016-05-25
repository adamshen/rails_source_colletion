require 'open-uri'
require 'nokogiri'

class CatchUpError < StandardError;
end

class NODecsError < StandardError
end
CATCH_OPTIONS = %q(q=language%3Aruby+stars%3A%3E500+fork%3Atrue&ref=advsearch&type=Repositories&utf8=%E2%9C%93)

total = 1
total_match = 1
page_range = 1..100

`rm log`
`cp list_head.md list.md`

page_range.each do |n|
  fetch_retry_times = 3

  begin
    page = Nokogiri::HTML(open("https://github.com/search?l=&p=#{n}&#{CATCH_OPTIONS}"))
    repos = page.css('.repo-list-name a')
    descriptions = page.css('.repo-list-description')

    raise NODecsError if descriptions.length < 10
  rescue OpenURI::HTTPError
    raise CatchUpError if fetch_retry_times == 0
    fetch_retry_times -= 1
    sleep 3
    retry
  rescue NODecsError
    `echo "Error -- page:#{n} repos:#{repos.map(&:text).join(' ')}" >> log`
    next
  end

  (0..9).each do |num|
    repo = repos[num]
    m = /(\w.+)\s/.match(descriptions[num])
    description = m ? m[1] : ""

    url = repo.attributes["href"].value
    name = repo.text

    puts "#{total}: #{name}"
    `echo "#{total}: #{name}" >> log`
    total += 1

    begin
      open("https://github.com#{url}/blob/master/app/controllers/application_controller.rb")
    rescue OpenURI::HTTPError
      next
    end

    `echo "| [#{name}](https://github.com#{url}) | #{description} |" >> list.md`
    `echo "Matched!" >> log`
    total_match += 1
  end

  sleep 3
end