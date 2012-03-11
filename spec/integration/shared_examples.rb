
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


