$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2020-09-25', '2020-09-26', '2020-09-27', '2020-09-28',
    '2020-09-29', '2020-09-30', '2020-10-01', '2020-10-02',
    '2020-10-03', '2020-10-04', '2020-10-05'
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
