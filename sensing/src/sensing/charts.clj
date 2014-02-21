(ns sensing.charts
  (:require
    (incanter (charts :as charts)))
  (:use
    [sensing.data :only [sensors locations get-time smooth query-location query-locations]]))

(defn- smooth-data [sens-id data]
  [(get-time data) (smooth sens-id data)])

(defn- create-chart [sens-id loc-id data]
  (let [[x y] (smooth-data sens-id data)]
    (charts/time-series-plot x y :x-label "Time" :y-label (sensors sens-id) :series-label (locations loc-id) :legend true)))

(defn- add-to-chart [chart sens-id loc-id data]
  (let [[x y] (smooth-data sens-id data)]
    (charts/add-lines chart x y :series-label (locations loc-id))))

(defn make-initial-chart [sens-id loc-id period]
  (create-chart sens-id loc-id (query-location sens-id loc-id period)))

(defn add-location [chart sens-id loc-id period]
  (add-to-chart chart sens-id loc-id (query-location sens-id loc-id period)))

(defn make-chart [sens-id loc-ids period]
  (let [loc-ids (vec (sort loc-ids))
        data (vec (query-locations sens-id loc-ids period))]
    (reduce (fn [chart i]
              (add-to-chart chart sens-id (loc-ids i) (data i)))
            (create-chart sens-id (first loc-ids) (first data))
            (range 1 (count loc-ids)))))
