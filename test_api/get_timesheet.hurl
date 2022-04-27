# I want to see what project a consultant has worked on for each day of a month, aka their timesheet for that month

## It returns 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200

## It returns JSON

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200
[Asserts]
header "Content-Type" == "application/json"

## It requires consultant query param

GET http://localhost:8788/timesheets?month=2022-04
HTTP/* 400

## It requires month query param

GET http://localhost:8788/timesheets?consultant=RDA
HTTP/* 400

## It returns the correct JSON structure

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$['2022-04-01']" == "eat_cakes"
jsonpath "$['2022-04-02']" == "race"

## It returns different results for another consultant

GET http://localhost:8788/timesheets?consultant=TSP&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$['2022-04-01']" == "friendship_magic"
jsonpath "$['2022-04-02']" == "celestia"

## It returns different results for another month

GET http://localhost:8788/timesheets?consultant=TSP&month=2022-03
HTTP/* 200
[Asserts]
jsonpath "$['2022-03-01']" == "friendship_magic"
jsonpath "$['2022-03-02']" == "celestia"

# It returns an empty object if no days have a project

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-03
HTTP/* 200
[Asserts]
jsonpath "$" != null
