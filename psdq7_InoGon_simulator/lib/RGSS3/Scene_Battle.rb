class Scene_Battle
  def start
    BattleManager.battle_start
    start_party_command_selection
  end

  def update
    if BattleManager.in_turn?
      process_action
    end
    BattleManager.judge_win_loss
  end

  def start_party_command_selection
    BattleManager.input_start
    turn_start
  end

  def turn_start
    @subject =  nil
    BattleManager.turn_start
  end

  def turn_end
    all_battle_members.each do |battler|
      battler.on_turn_end
    end
    BattleManager.turn_end
    start_party_command_selection
  end

  def all_battle_members
    $game_party.members + $game_troop.members
  end

  def process_action
    if !@subject || !@subject.current_action
      @subject = BattleManager.next_subject
    end
    return turn_end unless @subject
    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action.valid?
        execute_action
      end
      @subject.remove_current_action
    end
    process_action_end
  end

  def process_action_end
    @subject.on_action_end
    # @log_window.display_auto_affected_status(@subject)
  end

  def execute_action
    use_item
  end

  def use_item
    item = @subject.current_action.item
    targets = @subject.current_action.targets.compact
    log(@subject.current_action.to_s, :action)
    @subject.use_item(item)
    targets.each.with_index {|target, index|
      target.item_apply(@subject, item, index)
      s = target.result.to_s
      log(s, :result) if s
    }
  end

  def test
    start
    loop {
      res = update
      return res if res
    }
  end
end
