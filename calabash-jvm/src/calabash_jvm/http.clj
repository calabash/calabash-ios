(ns calabash-jvm.http
  (:require [clojure.data.json :as json]
            [clj-http.client :as client]
            [clj-http.conn-mgr :as mgr]
            [clojure.tools.logging :as lg]
            [clj-logging-config.log4j :as l4j]
            [calabash-jvm.env :as env])
  (:import (java.security KeyStore)
           (org.apache.http.impl.conn.tsccm ThreadSafeClientConnManager)))

(def ^:dynamic *conn-timeout* 60000)
(def ^:dynamic *socket-timeout* 60000)


(declare error!)
(declare is-error?)


(defn- mk-conn-mgr
  []
  (mgr/make-reusable-conn-manager {:timeout *conn-timeout*}))

(def ^:private ^:dynamic *conn-mgr*  (mk-conn-mgr))


(defn req
  "Makes http according to spec, with json body"
  ([spec] (req spec nil))
  ([spec body]
     (binding [mgr/*connection-manager* *conn-mgr*]
       (let [http-method (ns-resolve 'clj-http.client (symbol  (name (:method spec))))
              uri (env/resource (:path spec))
             http-spec (merge {:content-type :json
                               :socket-timeout *socket-timeout*
                               :check-json? true
                               :conn-timeout *conn-timeout*
                               :retry-handler (fn [ex try-count http-context]
                                                (println "Retrying on:" ex)
                                                (<= try-count 2))}
                              spec)
              param-key (if (= (:method spec) :get)
                          :query-params
                          :body)
             rsp (http-method
                  uri
                  (if body
                    (assoc http-spec param-key (json/json-str body))
                    http-spec))]

         (if (is-error? rsp (:check-json? http-spec))
           (error! rsp)
           (:body rsp))))))


(defn op-map [op & args]
  {:method_name op
   :arguments (or args [])})


(defn map-views
  "Reaches the map endpoint via POST.
   Takes a UIQuery, and op name and optional args"
  [query op & args]
  (:results (req {:method :post
                   :path "map"
                   :as :json}
                  {:query query
                   :operation (apply op-map op args)})))




(defn- is-error?
  [rsp check-json?]
  (or
   (>= (:status rsp) 400)
   (and check-json?
        (not=  (:outcome (:body rsp)) "SUCCESS"))))

(defn- error!
  [{body :body}]
  (prn body)
  (throw (RuntimeException.
          (str "Failure: " (:reason body) "\n"
               "Details: " (:details body) "\n"))))
