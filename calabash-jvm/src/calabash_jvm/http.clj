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

(defn- mk-conn-mgr
  []
  (mgr/make-reusable-conn-manager {:timeout *conn-timeout*}))

(def ^:private ^:dynamic *conn-mgr*  (conn-mgr))


(defn op-map [op & args]
  (let [m {:method_name op}]
    (if args
      (merge m {:arguments args})
      m)))

(declare error)


(defn map*
  [endpoint query op & args]
  (binding [mgr/*connection-manager* *conn-mgr*]
    (let [body (json/json-str {:query query
                               :operation (apply op-map op args)})
          rsp
          (client/post endpoint
                       {:body  body
                        :content-type :json
                        :socket-timeout *socket-timeout*
                        :conn-timeout *conn-timeout*
                        :accept :json
                        :retry-handler (fn [ex try-count http-context]
                                         (println "Got:" ex)
                                         (if (> try-count 1) false true))
                        :as :json})]
      (if (or
           (not= (:status rsp) 200)
           (not= (:outcome (:body rsp) "SUCCESS")))
        (error rsp)
        (:results (:body rsp))))))

(defn cmap
  [query op & args]
  (apply map* (env/resource "map") query op args))

(defn- error
  [{body :body}]
  (throw (RuntimeException.
          (str "Failure: " (:reason body)
               " Details: " (:details body)))))
