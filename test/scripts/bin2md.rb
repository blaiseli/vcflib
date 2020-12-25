#!/usr/bin/env ruby
#
# Internal helper script to create a markdown file from binaries
#
# The --index option creates the index page
#
#    bin2md [--index] erbtemplate [binary]
#
# by Pjotr Prins (C) 2020

require 'erb'
require 'date'
require 'open3'

VERSION=`cat ../VERSION`.strip
template = ARGV.shift
create_index = false
if template == "--index"
  create_index = true
  template = ARGV.shift
end
search = ARGV.shift

bindir = '../build'
$stderr.print("--- Parsing the bin files in #{bindir} for #{VERSION}\n")

Dir.glob(bindir+'/*').each do|bin|
  if !File.directory?(bin) and File.executable?(bin)
    if search and bin !~ /#{search}/
      next
    end
    cmd = File.basename(bin)
    help_cmd = cmd + " -h"
    $stderr.print("    "+bin+"\n")
    stdout, stderr, status = Open3.capture3(bin+" -h")
    out = stderr + stdout
    if out == ""
      help_cmd = cmd
      stdout, stderr, status = Open3.capture3(bin)
      out = stderr + stdout
    end
    # $stderr.print(out)
    usage_full = out
    lines = (out).split("\n")
    pydoc_full = lines.map{|l| l=="" ? ">" : l }.join("\n")
    in_usage = false
    usage = []
    other = []
    lines.each do | l |
      if l =~ /usage/i
        in_usage = true
      end
      if in_usage
        if l == ""
          in_usage = false
          next
        end
        usage << l
      else
        other << l
      end
    end
    descr = []
    rest = other
    type = "unknown"
    other.each do | l |
      if l =~ /type: (\S+)/i
        type = $1
        break
      end
    end

    other.each do | l |
      break if l == ""
      descr << l
    end
    body = rest.drop(descr.size).join("\n")
    usage = usage.join(" ").gsub(/#{VERSION}\s+/,"")
    usage = usage.sub(/\.\.\/build\//,"")
    pydoc_full = pydoc_full.gsub(/#{VERSION}\s+/,"")
    pydoc_full = pydoc_full.gsub(/\.\.\/build\//,"")
    # pydoc_full = pydoc_full.gsub(/vcflib/,"VCF")
    descr = descr.join(" ").gsub(/#{VERSION}\s+/,"")
    descr = descr.sub(/vcflib/,"VCF")
    # print("HELP:",help_cmd,"\n")
    # print("DESCRIPTION:",descr,"\n")
    # print("USAGE:",usage,"\n")
    # print("TYPE:",type,"\n")
    # print("BODY:",body,"\n")

    d = DateTime.now

    year = d.year

    b = binding
    renderer = ERB.new(File.read(template))
    print renderer.result(b)

  end
end
