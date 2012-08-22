(ns calabash-jvm.utils)

(defn file-or-nil
  [name]
  (let [f (clojure.java.io/file name)]
    (when (.exists f) f)))

(defn pwd
  "get current working directory"
  []
  (. System getProperty "user.dir"))
