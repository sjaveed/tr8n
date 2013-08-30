require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe Hash do
  context "extensions" do
    describe "combinations" do
      it "should generate correct combinations" do
        {
          :a => [1, 2],
          :b => [1, 2]
        }.combinations.should eq([{:b=>1, :a=>1}, {:b=>1, :a=>2}, {:b=>2, :a=>1}, {:b=>2, :a=>2}])


        # single context with each token (multiple rules per context)
        {
            :actor => ["gender:male", "gender:female", "gender:unknown"],
            :target => ["gender:male", "gender:female", "gender:unknown"]
        }.combinations.should eq([{:target=>"gender:male", :actor=>"gender:male"},
                                  {:target=>"gender:male", :actor=>"gender:female"},
                                  {:target=>"gender:male", :actor=>"gender:unknown"},
                                  {:target=>"gender:female", :actor=>"gender:male"},
                                  {:target=>"gender:female", :actor=>"gender:female"},
                                  {:target=>"gender:female", :actor=>"gender:unknown"},
                                  {:target=>"gender:unknown", :actor=>"gender:male"},
                                  {:target=>"gender:unknown", :actor=>"gender:female"},
                                  {:target=>"gender:unknown", :actor=>"gender:unknown"}])

        {
            :actor => ["male", "female", "unknown"],
            :count => ["one", "other"]
        }.combinations.should eq([{:count=>"one", :actor=>"male"}, {:count=>"one", :actor=>"female"},
                                  {:count=>"one", :actor=>"unknown"}, {:count=>"other", :actor=>"male"},
                                  {:count=>"other", :actor=>"female"}, {:count=>"other", :actor=>"unknown"}])


        # multiple contexts of the same token - rare but possible
        {
            :actor    =>   ["male", "female", "unknown"],
            :actor_1  =>   ["vowels", "other"],
            :count    =>   ["one", "other"]
        }.combinations.should eq([{:count=>"one", :actor_1=>"vowels", :actor=>"male"},
                                  {:count=>"one", :actor_1=>"vowels", :actor=>"female"},
                                  {:count=>"one", :actor_1=>"vowels", :actor=>"unknown"},
                                  {:count=>"one", :actor_1=>"other", :actor=>"male"},
                                  {:count=>"one", :actor_1=>"other", :actor=>"female"},
                                  {:count=>"one", :actor_1=>"other", :actor=>"unknown"},
                                  {:count=>"other", :actor_1=>"vowels", :actor=>"male"},
                                  {:count=>"other", :actor_1=>"vowels", :actor=>"female"},
                                  {:count=>"other", :actor_1=>"vowels", :actor=>"unknown"},
                                  {:count=>"other", :actor_1=>"other", :actor=>"male"},
                                  {:count=>"other", :actor_1=>"other", :actor=>"female"},
                                  {:count=>"other", :actor_1=>"other", :actor=>"unknown"}])

      end
    end
  end
end
