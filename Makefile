default: build

build:
	docker build -t image-builder-odroid-c1 .

sd-image: build
	docker run --rm --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules image-builder-odroid-c1

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules image-builder-odroid-c1 bash

testshell: build
	docker run -ti --privileged -v $(shell pwd)/builder:/builder -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules image-builder-odroid-c1 bash

tag:
	git tag ${TAG}
	git push origin ${TAG}
