class Object
  def ruby_version_is(*args)
    yield
  end

  def ruby_bug(bug, version)
    yield
  end
end
