(ns sensing.data
  (:require
    (korma (db :as db) (core :as k))
    (incanter (charts :as charts))
    (clj-time (core :as t) (local :as local) (coerce :as coerce))))

(db/defdb sensordb (db/mysql {:db "sensors" :user "sensors" :password "s3ns0rs" :host "rho" :delimiters ""}))
(k/defentity sensordata (k/database sensordb))
(k/defentity nodes (k/database sensordb))
(k/defentity weather (k/database sensordb))

(defn- unixtime [d]
  (long (/ (coerce/to-long d) 1000)))

(defn- query-window [q [off dur]]
  (let [now (local/local-now)
        start (t/minus now off)
        end (t/plus start dur)]
    (-> q
        (k/where {:time [> (k/sqlfn from_unixtime (unixtime start))]})
        (k/where {:time [< (k/sqlfn from_unixtime (unixtime end))]})
        (k/where {:th_status 0})
        (k/select))))

; computes a rolling average of the data
(defn- avg [n data]
  (let [f (take n data)]
    (first
      (reduce (fn [[r w s] d]
                (let [s (+ s d (- (w 0)))]
                  [(conj r (/ s n)) (conj (subvec w 1) d) s]))
              [[] (vec f) (apply + f)]
              (drop n data)))))

(defn- valid [key data]
  (let [ranges {:light [0 255], :battery [0 1.5], :humidity [0 100], :temperature [0 30]}
        [lo hi] (ranges key)]
    (filter (fn [d] (and (>= d lo) (<= d hi))) data)))

(def sensors {:light "Light", :battery "Battery", :humidity "Humidity", :temperature "Temperature"})

(def locations (reduce (fn [m {:keys [id location]}] (assoc m id location))
                       {} (k/select nodes (k/fields :id :location))))

(defn- window [q [off dur]]
  (let [now (local/local-now)
        start (t/minus now off)
        end (t/plus start dur)]
    (-> q
        (k/where {:time [> (k/sqlfn from_unixtime (unixtime start))]})
        (k/where {:time [< (k/sqlfn from_unixtime (unixtime end))]}))))

(defn query-location [sensor loc time-window]
  (-> (k/select* sensordata)
      (k/fields :time sensor)
      (k/where {:node_id [= loc]})
      (k/where {:th_status 0})
      (k/order :time)
      (window time-window)
      (k/select)))

(defn query-locations [sensor locs time-window]
  (partition-by :node_id
                (-> (k/select* sensordata)
                    (k/fields :time :node_id sensor)
                    (k/where {:node_id [in locs]})
                    (k/where {:th_status 0})
                    (k/order :node_id)
                    (k/order :time)
                    (window time-window)
                    (k/select))))

(defn query-weather [time-window]
  (-> (k/select* weather)
      (k/fields :temperature :humidity :visibility :pressure :feels_like :direction :speed :gust :icon :time)
      (k/order :time)
      (window time-window)
      (k/select)))

(defn get-time [data]
  (map #(.getTime (:time %)) data))

(defn smooth [key data]
  (->> data
       (map key)
       (valid key)
       (avg (inc (int (/ (count data) 250))))))

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