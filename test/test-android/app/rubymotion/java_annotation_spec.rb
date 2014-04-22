class Java_Annotation_Test < Java::Lang::Object
  __annotation__('@android.webkit.JavascriptInterface')
  def foo
    42
  end
end

describe "Java annotations" do
  it "can be attached to Ruby methods using the __annotation__() class method" do
    method = Java_Annotation_Test.getMethod('foo', [])
    method.should != nil
    annotations = method.getDeclaredAnnotations
    annotations.size.should == 1
    annotations[0].toString.should == '@android.webkit.JavascriptInterface()'
  end
end
