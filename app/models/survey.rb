class Survey < ActiveRecord::Base
  belongs_to :project
  has_and_belongs_to_many :survey_items, -> { order('survey_items_surveys.position') }
  has_many :responses
  belongs_to :target_list
  has_many :target_pools, -> { order('target_id') }
  
  def next_target(user)
    behavior = self.behavior
    completed_targets = Array.new
    locked_target = self.target_pools.where(:user_id => user.id, :completed => false)
    p "locked target"
    p locked_target
    if behavior == "Sequential Distinct"
      self.target_pools.where(:completed => true).collect {|pool| completed_targets << pool.target_id }
    elsif behavior == "Sequential"
      self.target_pools.where(:user_id => user.id, :completed => true).collect {|pool| completed_targets << pool.target_id }
    end  
    
    if self.target_pools.empty?
      TargetPool.create(:user_id => user.id, :target_id => self.target_list.targets.first.id, :survey_id => self.id, :locked => true, :completed => false)
      return self.target_list.targets.first
    elsif !locked_target[0].nil? 
      return Target.find(locked_target[0].target_id)  
    else  
      self.target_list.targets.each do |target|
        unless completed_targets.include?(target.id)
          TargetPool.create(:user_id => user.id, :target_id => target.id, :survey_id => self.id, :locked => true, :completed => false)
          return target
        else
          return nil  
        end  
      end  
    end  
  end  
end
