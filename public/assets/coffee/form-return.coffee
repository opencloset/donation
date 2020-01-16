$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2020-01-22', '2020-01-23', '2020-01-24', '2020-01-25',
    '2020-01-26', '2020-01-27', '2020-01-28', '2020-01-29'
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
