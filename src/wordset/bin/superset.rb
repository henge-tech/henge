def superset_rex(pattern)
  affix = pattern.split(/_/)
  prefix = ''
  affix[0].to_s.split(//).reverse.each do |c|
    if prefix.empty?
      prefix = "(?:#{c})?"
    else
      prefix = "(?:#{c}#{prefix})?"
    end
  end

  suffix = ''
  affix[1].to_s.split(//).each do |c|
    if suffix.empty?
      suffix = "(?:#{c})?"
    else
      suffix = "(?:#{suffix}#{c})?"
    end
  end

  return /^#{prefix}_#{suffix}$/
end

def subset_rex(pattern)
  affix = pattern.split(/_/)
  return /^#{affix[0]}.*_.*#{affix[1]}$/
end
