apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: grpc-server
spec:
  replicas: 2
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: grpc-server
  template:
    metadata:
      labels:
        app: grpc-server
    spec:
      volumes:
        - name: envoy
          configMap:
            name: envoy-grpc-server-config
      containers:
        - name: grpc-server
          image: gcr.io/istsh-sample/grpc-server:COMMIT_SHA
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
          command: ["/server"]
          readinessProbe:
            exec:
              command: [ "/bin/grpc_health_probe", "-addr=:8080" ]
            initialDelaySeconds: 1
          livenessProbe:
            exec:
              command: [ "/bin/grpc_health_probe", "-addr=:8080" ]
            initialDelaySeconds: 1
        - name: envoy-proxy
          image: envoyproxy/envoy:v1.14-latest
          imagePullPolicy: Always
          command:
            - "/usr/local/bin/envoy"
          args:
            - "--config-path /etc/envoy/envoy.yaml"
          ports:
            - name: app
              containerPort: 10000
            - name: envoy-admin
              containerPort: 8001
          volumeMounts:
            - name: envoy
              mountPath: /etc/envoy
  strategy:
    blueGreen:
      # 本番アクセス用のServiceの名前
      activeService: grpc-server-active
      # Previewアクセス用のServiceの名前
      previewService: grpc-server-preview
      # 自動昇格の有無
      autoPromotionEnabled: true
      # オプション Preview環境限定でreplicasの上書き
      # previewReplicaCount: 1
      # オプション ReplicaSetが準備完了になってから自動昇格するまでの時間
      autoPromotionSeconds: 15
      # オプション 新Verにルーティングを切り替えた後に旧VerのPodのスケールダウンを開始させるまでの時間
      scaleDownDelaySeconds: 30
