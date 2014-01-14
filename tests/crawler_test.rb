require 'minitest/autorun'

# TODO!

class TestFilePaths < MiniTest::Unit::TestCase
  tests = {
    "" => "index.html"
    "/" => "index.html"
    "/asdfdf/dfdf" => "/asdfdf/dfdf"
    "/asdfdf/dfdf/" => "/asdfdf/dfdf" and "/asdfdf/dfdf/index.html"
    "/asdfad/asdffd.test" => "/asdfad/asdffd.test"
    "/?asdfsd=12312" => "/?asdfsd=12312"
    "/asdfad/asdffd.test?123=sdff" => "/asdfad/asdffd.test?123=sdff"
  }
end