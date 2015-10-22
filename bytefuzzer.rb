#!/usr/bin/env ruby

unless ARGV.size.eql?(6)
  raise "Try invoking like this: #{ARGV[0]} './sample.sh' 0 255 0 10 10'"
end

# variables (will be put into option parser later)
dir = 'fuzzes'

cmd                    = ARGV[0] # e.g. sample.sh, a wrapper around 'cat -'
minimum, maximum       = ARGV[1].to_i, ARGV[2].to_i # 0-255
min_length, max_length = ARGV[3].to_i, ARGV[4].to_i # in bytes
iterations             = ARGV[5].to_i

# setup
Dir.mkdir(dir) unless File.exists?(dir)

def main(cmd, dir, minimum, maximum, min_length, max_length, iterations)
  (0...iterations).each do |i|
    fn = File.join(dir, "case-#{i+1}")
    success, input, msg = test_case(dir, cmd, minimum, maximum,
                                    min_length, max_length, fn)
    puts "#{i+1} of #{iterations}: #{msg}"
  end
end

def test_case(dir, cmd, minimum, maximum, min_length, max_length, in_fn)
  out_fn = in_fn + '_result'
  length = rand(max_length - min_length) + min_length
  input = data(length, minimum, maximum)

  # TODO: use stdio and pipes instead of writing to disk
  f = File.open(in_fn, 'wb')
  f.syswrite(input)
  f.close()

  c = "cat #{in_fn} | #{cmd} > #{out_fn}"
  `#{c}`

  success = same?(in_fn, out_fn)

  if success
    File.delete(in_fn)
    File.delete(out_fn)
    return success, input, "PASS. #{length} bytes, #{minimum}, #{maximum}: #{in_fn}"
  else
    # leave fuzzies around if failure
    return success, input, "FAIL. #{length} bytes, #{minimum}, #{maximum}: #{in_fn}"
  end
end

def same?(fn0, fn1)
  `diff #{fn0} #{fn1} | head -n 1`.strip.size.zero?
end

def data(length, minimum, maximum)
  Array.new(length) { rand(maximum-minimum) + minimum }.pack('c*')
end

main(cmd, dir, minimum, maximum, min_length, max_length, iterations)
