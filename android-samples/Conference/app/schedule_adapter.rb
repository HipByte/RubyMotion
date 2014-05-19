class ScheduleAdapter < Android::Widget::ArrayAdapter
  def schedule=(schedule)
    @schedule = schedule
  end

  def getView(position, convertView, parent)
    titleTextView = Android::Widget::TextView.new(context)
    titleTextView.text = @schedule[position][:title]
    titleTextView.textSize = 20.0
    titleTextView.setTypeface(nil, Android::Graphics::Typeface::BOLD)
    titleTextView.textColor = Android::Graphics::Color::BLACK

    whenTextView = Android::Widget::TextView.new(context)
    whenTextView.text = @schedule[position][:when]
    whenTextView.textSize = 16.0
    whenTextView.textColor = Android::Graphics::Color::BLACK
    whenTextView.gravity = Android::View::Gravity::CENTER_VERTICAL

    whoTextView = nil
    if who = @schedule[position][:who]
      whoTextView = Android::Widget::TextView.new(context)
      whoTextView.text = who
      whoTextView.textSize = 16.0
      whoTextView.textColor = Android::Graphics::Color::BLACK
    else
      titleTextView.gravity = Android::View::Gravity::CENTER_VERTICAL
    end

    if whoTextView
      layout1 = Android::Widget::LinearLayout.new(context)
      layout1.orientation = Android::Widget::LinearLayout::VERTICAL
      layout1.addView(titleTextView)
      layout1.addView(whoTextView)
    else
      layout1 = titleTextView
    end

    whenTextView.setPadding(20, 10, 10, 10)
    layout1.setPadding(10, 10, 10, 10)

    layout2 = Android::Widget::LinearLayout.new(context)
    layout2.orientation = Android::Widget::LinearLayout::HORIZONTAL
    layout2.addView(whenTextView, 170, -1)
    layout2.addView(layout1, -1, 130)
    layout2
  end
end
