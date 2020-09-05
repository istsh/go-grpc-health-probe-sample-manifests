apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: grpc-gateway
spec:
  replicas: 1
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: grpc-gateway
  template:
    metadata:
      labels:
        app: grpc-gateway
    spec:
      volumes:
        - name: envoy
          configMap:
            name: envoy-grpc-gateway-config
      containers:
        - name: grpc-gateway
          image: gcr.io/istsh-sample/grpc-gateway:COMMIT_SHA
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
          command: ["/reverse-proxy", "--grpc-server-endpoint=127.0.0.1:9090"]
          readinessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 1
          livenessProbe:
            httpGet:
              path: /v1/health
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 1
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
      activeService: grpc-gateway-active
      # Previewアクセス用のServiceの名前
      previewService: grpc-gateway-preview
      # 自動昇格の有無
      autoPromotionEnabled: true
      # オプション Preview環境限定でreplicasの上書き
      # previewReplicaCount: 1
      # オプション ReplicaSetが準備完了になってから自動昇格するまでの時間
      autoPromotionSeconds: 15
      # オプション 新Verにルーティングを切り替えた後に旧VerのPodのスケールダウンを開始させるまでの時間
      scaleDownDelaySeconds: 30
