require 'contest'
require 'tilt'

begin
  require 'coffee_script'

  module CoffeeScriptTests
    def self.included(mod)
      mod.class_eval do
        unless method_defined?(:assert_not_match)
          # assert_not_match is missing on 1.8.7, which uses assert_no_match
          def assert_not_match(a, b)
            unless a.kind_of?(Regexp)
              a = Regexp.new(Regexp.escape(a))
            end
            assert_no_match(a,b)
          end
        end

        test "bare is disabled by default" do
          assert_equal false, @renderer.default_bare
        end

        test "compiles and evaluates the template on #render" do
          template = @renderer.new { |t| @code_without_variables }
          assert_match "puts('Hello, World!');", template.render
        end

        test "can be rendered more than once" do
          template = @renderer.new { |t| @code_without_variables }
          3.times { assert_match "puts('Hello, World!');", template.render }
        end

        test "disabling coffee-script wrapper" do
          template = @renderer.new { @code_with_variables }
          assert_match "(function() {", template.render
          assert_match "puts(\"Hello, \" + name);\n", template.render

          template = @renderer.new(:bare => true) { @code_with_variables }
          assert_not_match "(function() {", template.render
          assert_equal "var name;\n\nname = \"Josh\";\n\nputs(\"Hello, \" + name);\n", template.render

          template2 = @renderer.new(:no_wrap => true) { @code_with_variables}
          assert_not_match "(function() {", template.render
          assert_equal "var name;\n\nname = \"Josh\";\n\nputs(\"Hello, \" + name);\n", template.render
        end

        context "wrapper globally enabled" do
          setup do
            @bare = @renderer.default_bare
            @renderer.default_bare = false
          end

          teardown do
            @renderer.default_bare = @bare
          end

          test "no options" do
            template = @renderer.new { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_match "(function() {", template.render
          end

          test "overridden by :bare" do
            template = @renderer.new(:bare => true) { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_not_match "(function() {", template.render
          end

          test "overridden by :no_wrap" do
            template = @renderer.new(:no_wrap => true) { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_not_match "(function() {", template.render
          end
        end

        context "wrapper globally disabled" do
          setup do
            @bare = @renderer.default_bare
            @renderer.default_bare = true
          end

          teardown do
            @renderer.default_bare = @bare
          end

          test "no options" do
            template = @renderer.new { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_not_match "(function() {", template.render
          end

          test "overridden by :bare" do
            template = @renderer.new(:bare => false) { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_match "(function() {", template.render
          end

          test "overridden by :no_wrap" do
            template = @renderer.new(:no_wrap => false) { |t| @code_with_variables }
            assert_match "puts(\"Hello, \" + name);", template.render
            assert_match "(function() {", template.render
          end
        end
      end
    end
  end

  class CoffeeScriptTemplateTest < Test::Unit::TestCase
    setup do
      @code_without_variables = "puts 'Hello, World!'\n"
      @code_with_variables = 'name = "Josh"; puts "Hello, #{name}"'
      @renderer = Tilt::CoffeeScriptTemplate
    end

    include CoffeeScriptTests

    test "is registered for '.coffee' files" do
      assert_equal @renderer, Tilt['test.coffee']
    end
  end

rescue LoadError => boom
  warn "Tilt::CoffeeScriptTemplate (disabled)"
end
