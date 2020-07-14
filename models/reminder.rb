class Reminder < Sequel::Model(DB[:reminders])
  BY_TRIGGER_ON_FIRST = [
    Sequel.lit('CASE WHEN trigger_on IS NULL THEN 1 ELSE 0 END, trigger_on ASC'),
    Sequel.desc(:priority),
  ]
  BY_PRIORITY_FIRST = [
    Sequel.desc(:priority),
    Sequel.asc(:trigger_on),
  ]

  def self.by_priority
    order(Sequel.desc(:priority), Sequel.asc(:trigger_on))
  end

  def self.compute_code(code:, from:)
    add_rand_minutes = if code.chomp!('~')
                         rand(1..59)
                       else
                         0
                       end
    suffix = code[-1]
    i = Integer(code[0..-2])
    next_trigger_on = case suffix
                      when 'm'
                        from + i*MINUTES
                      when 'h'
                        from + i*HOURS
                      when 'd'
                        from + i*DAYS
                      when 'w'
                        from + i*WEEKS
                      when 'M'
                        (from.to_datetime >> i).to_time
                      else
                        fail 'Impossible'
                      end

    next_trigger_on + (add_rand_minutes*MINUTES)
  end

  def self.next(code)
    from = compute_code(code: code, from: Time.now)

    prioritized
      .where{ trigger_on <= from }
  end

  def self.upto(time_code)
    ts = parse_date_str(time_code)
    prioritized
      .where{ trigger_on < ts }
  end

  def reschedule(from:, code:)
    next_trigger_on = Reminder.compute_code(code: code, from: from)
    res = update(trigger_on: next_trigger_on)
    autofill!
    p(:RESCHEDULE_OK)
  end

  def reschedule2(time_code:)
    next_trigger_on = parse_date_str(time_code)
    res = update(trigger_on: next_trigger_on)
    autofill!
    p(:RESCHEDULE2_OK)
  end

  def autofill!
    if descr.start_with?('bday[')
      autofill_bday!
    end
  end

  def autofill_bday!
    # "bday[NAME, BDATE]"
    m = descr.match(/bday\[(.+)\]/)
    abort('Bad bday tag') if m.nil?

    # "NAME, BDATE"
    raw_data = m[1]
    abort('Bad bday tag: could not extract raw data') if raw_data.nil?
    name, bdate_str = raw_data.split(',').map(&:strip)
    abort('Bad bday tag: could not extract name') if name.nil?
    abort('Bad bday tag: could not extract bdate_str') if bdate_str.nil?

    bdate = Date.parse(bdate_str)
    ref_date = trigger_on.to_date
    next_bday = Date.new(ref_date.year, bdate.month, bdate.day)
    age = next_bday.year - bdate.year
    self.descr = "bday[#{name}, #{bdate_str}] : #{age} years old on #{next_bday.strftime("%d %B %Y (%A)")}"
  end

  def notify_phone_required?
    return false if priority < 100
    return true if phone_notified_on.nil?

    last_notified_since = Integer(Time.now - phone_notified_on)
    retrigger_after = 24 / (priority/100.0/60.0)
    return last_notified_since > retrigger_after*MINUTES
  end

  def validate
    super
    errors.add(:priority, 'cannot be nil') if priority.nil?
    errors.add(:priority, 'is too high') if priority && priority > 4800
    errors.add(:descr, 'cannot be empty') if descr.nil? || descr.empty?
    errors.add(:trigger_on, 'cannot be empty on non negative priority') if priority >= 0 && trigger_on.nil?
    errors.add(:trigger_on, 'should be nil on negative priority') if priority < 0 && trigger_on
  end

  def notify_msg
    "[#{id}] Priority=#{priority}: #{descr}"
  end

  def notify!
    # dbus-monitor --session interface='org.freedesktop.Notifications'
    # Inspect args
    # NOTIFICATION_INTERFACE.methods['Notify']

    since_sec = Time.now - trigger_on
    do_not_replace = 0
    replaces_id = notification_id || do_not_replace
    icon = ''
    title = "#{notify_msg} (#{human_sec(since_sec)})"
    body = ''
    actions = []
    critical_variant = DBus.variant(DBUS_ASCII_TYPE_CODE.fetch(:byte), NOTIFY_URGENCY.fetch(:critical))
    hints = {'urgency' => critical_variant }
    timeout = NOTIFY_TIMEOUT.fetch(:never)
    nid = NOTIFICATION_INTERFACE.Notify(
      'reminder',
      replaces_id,
      icon,
      title,
      body,
      actions,
      hints,
      timeout,
    )

    if replaces_id != nid  # first notification since notification server has restarted
      update(notification_id: nid)
    end
  end

  def remove_notification!(delete: false)
    update(phone_notified_on: nil) unless delete
    return if notification_id.nil?

    NOTIFICATION_INTERFACE.CloseNotification(notification_id)
    update(notification_id: nil) unless delete
  end

end

Reminder.plugin :subset_conditions

Reminder.dataset_module do
  subset :prioritized, -> { priority >= 0 }
  subset :overdue, -> {
    (priority >= 0) & (trigger_on <= Time.now)
  }

  # def self.overdue
  #   where {
  #     (priority >=0) & (trigger_on <= Time.now)
  #   }
  # end

  # def self.prioritized
  #   where{ priority >= 0 }
  # end
end
