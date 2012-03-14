(ns calabash-jvm.env)

(defn getenv [str] (System/getenv str))

(def ENDPOINT (or (getenv "DEVICE_ENDPOINT")
                  "http://localhost:37265"))

(def UUID (getenv "UUID"))

(defn err [req rsp]
  (lg/warn "Error: " req rsp))
