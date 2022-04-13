# I want to see what project a consultant has worked on for each day of a month, aka their timesheet for that month

## It returns the correct JSON structure

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$.days['2022-04-01']" == "eat_cakes"
jsonpath "$.days['2022-04-02']" == "race"

## It returns different results for another consultant

GET http://localhost:8788/timesheets?consultant=TSP&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$.days['2022-04-01']" == "friendship_magic"
jsonpath "$.days['2022-04-02']" == "celestia"
