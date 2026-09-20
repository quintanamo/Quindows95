<script setup>
import { computed, onUnmounted, ref } from 'vue'
import { useApplicationStore } from '@/stores/applications'

const props = defineProps(['id', 'title', 'canResize', 'content'])
const isMaximized = ref(false)
const restoredPosition = ref({ left: '', top: '' })

const separatorIndex = props.content.indexOf(':')
const contentType = props.content.slice(0, separatorIndex)
const contentValue = props.content.slice(separatorIndex + 1)

const applications = useApplicationStore()
const application = computed(() =>
  applications.applications.find(app => app.id === props.id),
)
const isActive = computed(() => applications.getActiveIndex === props.id)
let dragState = null

const activateWindow = () => {
  applications.setActiveIndex(props.id)
}

const handleHeaderPointerDown = event => {
  if (event.target.closest('button') || isMaximized.value) return

  const windowElement = event.currentTarget.closest('.application-window')
  dragState = {
    startX: event.clientX,
    startY: event.clientY,
    startLeft: windowElement.offsetLeft,
    startTop: windowElement.offsetTop,
    container: windowElement.offsetParent,
    header: event.currentTarget,
    windowElement,
  }

  window.addEventListener('pointermove', handlePointerMove)
  window.addEventListener('pointerup', handlePointerUp, { once: true })
  event.currentTarget.setPointerCapture(event.pointerId)
  event.preventDefault()
}

const handlePointerMove = event => {
  if (!dragState) return

  const nextLeft = Math.max(
    0,
    dragState.startLeft + event.clientX - dragState.startX,
  )
  const maxTop = Math.max(
    0,
    dragState.container.clientHeight - dragState.header.offsetHeight,
  )
  const nextTop = Math.min(
    maxTop,
    Math.max(0, dragState.startTop + event.clientY - dragState.startY),
  )

  dragState.windowElement.style.left = `${nextLeft}px`
  dragState.windowElement.style.top = `${nextTop}px`
}

const handlePointerUp = () => {
  dragState = null
  window.removeEventListener('pointermove', handlePointerMove)
}

const handleClose = id => {
  applications.removeApplication(id)
}

const handleMinimize = id => {
  applications.minimizeApplication(id)
}

const toggleMaximize = event => {
  const windowElement = event.currentTarget.closest('.application-window')
  windowElement.classList.toggle('maximized')
  isMaximized.value = !isMaximized.value

  if (isMaximized.value) {
    restoredPosition.value = {
      left: windowElement.style.left,
      top: windowElement.style.top,
    }
    windowElement.style.left = '0px'
    windowElement.style.top = '0px'
  } else {
    windowElement.style.left = restoredPosition.value.left
    windowElement.style.top = restoredPosition.value.top
  }
}

onUnmounted(handlePointerUp)
</script>

<template>
  <article
    class="application-window"
    :id="props.id"
    :style="{ zIndex: application?.zIndex }"
    v-on:pointerdown="activateWindow"
  >
    <div
      class="application-window__header"
      v-on:pointerdown="handleHeaderPointerDown"
      v-on:dblclick="toggleMaximize"
    >
      <h2 style="font-weight: normal">{{ title }}</h2>
      <ul class="application-window__buttons">
        <li>
          <button
            class="application-window__button"
            style="line-height: 1rem"
            v-on:click="() => handleMinimize(props.id)"
          >
            _
          </button>
        </li>
        <li v-if="props.canResize">
          <button
            class="application-window__button"
            style="font-weight: bolder; line-height: 1.2rem"
            v-on:click="toggleMaximize"
          >
            {{ isMaximized ? '❐' : '☐' }}
          </button>
        </li>
        <li>
          <button
            class="application-window__button"
            v-on:click="() => handleClose(props.id)"
          >
            ✕
          </button>
        </li>
      </ul>
    </div>
    <div class="application-window__content">
      <iframe
        v-if="contentType === 'website'"
        ref="embeddedContent"
        :id="`${props.id}-object`"
        class="application-window__object"
        :src="contentValue"
        tabindex="0"
        :title="title"
        :style="{ pointerEvents: isActive ? 'auto' : 'none' }"
      ></iframe>
      <span v-else>Content type not supported</span>
    </div>
  </article>
</template>

<style lang="scss">
.application-window {
  position: absolute;
  border-top: 3px solid $color-gray;
  border-left: 3px solid $color-gray;
  border-right: 2px solid $color-gray-dark;
  border-bottom: 2px solid $color-gray-dark;
  box-shadow: 1px 1px 0px 1px $color-black;
  resize: both;
  overflow: hidden;
  width: 40rem;
  height: 30rem;
  min-height: 4rem;
  min-width: 22rem;
  background-color: $color-gray;

  &.maximized {
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    resize: none;
  }

  &__header {
    background-color: $color-blue;
    color: $color-white;
    width: 100%;
    height: 3rem;
    padding: 0 0.4rem;
    line-height: 3rem;
    vertical-align: middle;
    user-select: none;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    font-size: 1.2rem;
    display: flex;
    justify-content: space-between;
  }

  &__content {
    height: calc(100% - 3rem);
  }

  &__object {
    display: block;
    width: 100%;
    height: 100%;
    border: 0;
  }

  &__buttons {
    display: flex;
    gap: 0.4rem;
    list-style: none;
    align-items: center;
  }

  &__button {
    width: 1.8rem;
    height: 1.8rem;
    line-height: 1.8rem;
    vertical-align: middle;
    background-color: $color-gray;
    border-top: 1px solid $color-white;
    border-left: 1px solid $color-white;
    border-right: 1px solid $color-gray-dark;
    border-bottom: 1px solid $color-gray-dark;
    box-shadow: 1px 1px 0px 1px $color-black;
    color: $color-black;
    text-align: center;
  }
}
</style>
