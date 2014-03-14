
shared_examples_for :rating_model do
  its(:instance_methods) { should include(:rater) }
  its(:instance_methods) { should include(:rater=) }
  its(:instance_methods) { should include(:rater_id) }
  its(:instance_methods) { should include(:rater_id=) }

  its(:instance_methods) { should include(:rateable) }
  its(:instance_methods) { should include(:rateable=) }
  its(:instance_methods) { should include(:rateable_id) }
  its(:instance_methods) { should include(:rateable_id=) }
end

shared_examples_for :rateable_model do
  its(:methods) { should include(:rating_config_for) }
  its(:methods) { should include(:rating_model_for) }

  describe '.rating_model_for' do
    subject{ rateable_model.rating_model_for(passed_rater) }

    context 'when passing rater' do
      let(:passed_rater) { rater_model }
      it{ should == rating_model }
    end

    context 'when passing symbol' do
      let(:passed_rater) { rater_model.name.downcase.pluralize.to_sym }
      it{ should == rating_model }
    end
  end
end

shared_examples_for :rateable_instance do
  subject{ rateable }
  let(:average_rating_assoc_name) { "average_#{rater_model.name.underscore}_rating" }

  context 'when no rating exists' do
    it{ ;rateable.average_rating_of(rater_model).should == nil }
    it{ rateable.send(average_rating_assoc_name).should == nil }
  end

  context 'when one rating exists' do
    let(:rater) { rater_model.create }
    before{ rateable.rate(1,rater) }

    it{ rateable.average_rating_of(rater_model).should == 1 }
    it{ rateable.send(average_rating_assoc_name).should == 1 }
    it{ rateable.rating_of(rater, concern).rating.should == 1 }
    it{ rateable.rating_of(rater).rating.should == 1 }
  end

  context 'when multiple ratings exist' do
    let(:avg) { ratings.sum.to_f/ratings.length }
    let(:ratings) { 10.times.map{ (0..5).to_a.sample } }
    before{ ratings.each{ |r| rateable.rate(r,rater_model.create) } }

    it{ rateable.average_rating_of(rater_model).should == avg }
    it{ rateable.send(average_rating_assoc_name).should == avg }
  end
end
