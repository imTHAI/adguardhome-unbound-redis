IMAGE    = imthai/adguardhome-unbound-redis
WORKFLOW = docker.yml

test:
	docker build --platform linux/arm64 -t $(IMAGE):test .
	docker push $(IMAGE):test

ci:
	git push
	gh workflow run $(WORKFLOW)

.PHONY: test ci
