#!/usr/bin/env ruby

unless ARGV.size.eql?(5)
  raise "Try invoking like this: ./shag.rb './sample.sh' 0 255 10 10'"
end

# variables (will be put into option parser later)
dir = 'shags'

cmd              = ARGV[0] # e.g. sample.sh, a wrapper around 'cat -'
minimum, maximum = ARGV[1].to_i, ARGV[2].to_i # 0-255
max_length       = ARGV[3].to_i # in bytes
iterations       = ARGV[4].to_i

# setup
Dir.mkdir(dir) unless File.exists?(dir)

def main(cmd, dir, minimum, maximum, max_length, iterations)
  (0...iterations).each do |i|
    fn = File.join(dir, "case-#{i}")
    success, input, msg = test_case(dir, cmd, minimum, maximum, max_length, fn)
    puts "#{i+1} of #{iterations}: #{msg}"
  end
end

def test_case(dir, cmd, minimum, maximum, max_length, in_fn)
  out_fn = in_fn + '_result'
  length = rand(max_length)
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
    return success, input, "PASS. #{length}, #{minimum}, #{maximum}: #{in_fn}"
  else
    # leave fuzzies around if failure
    return success, input, "FAIL. #{length}, #{minimum}, #{maximum}: #{in_fn}"
  end
end

def same?(fn0, fn1)
  `diff #{fn0} #{fn1} | head -n 1`.strip.size.zero?
end

def data(length, minimum, maximum)
  #puts "making random data: #{length}bytes"
  (0..length).map do |n|
    x = rand(maximum-minimum) + minimum
    x
  end.pack('C*')
end

main(cmd, dir, minimum, maximum, max_length, iterations)
