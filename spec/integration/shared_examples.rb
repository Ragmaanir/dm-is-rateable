
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

end
