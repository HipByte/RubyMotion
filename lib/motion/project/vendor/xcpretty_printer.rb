# encoding: utf-8

module Motion; module Project; class Vendor;
  class XCPrettyPrinter
    include XCPretty::Printer

    def pretty_format(text)
      case text
      when /^ProcessPCH/
        print_pch_processing(text)
      when /^CompileC/
        print_compiling(text)
      when /^=== BUILD TARGET/
        print_build_target(text)
      when /^PhaseScriptExecution/
        print_run_script(text)
      when /^(Ld|Libtool)/
        print_linking(text)
      when /^CpResource/
        print_cpresource(text)
      when /^CopyStringsFile/
        print_copy_strings_file(text)
      when /^ProcessInfoPlistFile/
        print_processing_info_plist(text)
      else
        ""
      end
    end

    def optional_newline
      "\n"
    end

    def print_build_target(text)
      info = project_build_info(text)
      format("Build", "#{format_path(info[:project])}.xcodeproj [#{info[:target]} - #{info[:configuration]}]")
    end

    def print_processing_info_plist(text)
      format("Create", format_path(text.lines.first.shellsplit.last))
    end

    def print_pch_processing(text)
      @printed_pch_files ||= []
      path = text.shellsplit[2]
      if @printed_pch_files.include?(path)
        ''
      else
        @printed_pch_files << path
        format("Compile", format_path(path))
      end
    end

    def print_compiling(text)
      format("Compile", format_path(text.shellsplit[2]))
    end

    def print_run_script(text)
      format("Script", "'#{text.lines.first.shellsplit[1..-2].join(' ').gsub('\ ',' ')}'")
    end

    def print_linking(text)
      format("Link", format_path(text.shellsplit[1]))
    end

    def print_cpresource(text)
      format("Copy", format_path(text.shellsplit[1]))
    end

    def print_copy_strings_file(text)
      format("Copy", format_path(text.shellsplit))
    end

    def format_path(path)
      path = File.join(Dir.pwd, path)
      root = ENV['RM_XCPRETTY_PRINTER_PROJECT_ROOT']
      ".#{path[root.size..-1]}" # make relative to project root
    end

    def format(command, argument_text)
      result = "\e[1m#{command.rjust(10)}\e[0m #{argument_text}"
    end
  end
end; end; end

Motion::Project::Vendor::XCPrettyPrinter
