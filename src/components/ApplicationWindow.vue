<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import jsDosStyles from 'js-dos/dist/js-dos.css?raw'
import 'js-dos/dist/js-dos.js'
import { useApplicationStore } from '@/stores/applications'

const dosKeyboardGate = (() => {
  const originalAddEventListener = window.addEventListener.bind(window)
  const originalRemoveEventListener = window.removeEventListener.bind(window)
  const wrappedListeners = new WeakMap()
  let activeRegistration = null

  window.addEventListener = (type, listener, options) => {
    if (activeRegistration && (type === 'keydown' || type === 'keyup')) {
      const registrationOwner = activeRegistration.owner
      const wrappedListener = event => {
        if (registrationOwner()) listener.call(window, event)
      }

      let listenersByType = wrappedListeners.get(listener)
      if (!listenersByType) {
        listenersByType = new Map()
        wrappedListeners.set(listener, listenersByType)
      }
      listenersByType.set(type, wrappedListener)
      originalAddEventListener(type, wrappedListener, options)
      return
    }

    originalAddEventListener(type, listener, options)
  }

  window.removeEventListener = (type, listener, options) => {
    const wrapped = wrappedListeners.get(listener)?.get(type)
    originalRemoveEventListener(type, wrapped || listener, options)
  }

  return {
    register(owner, callback) {
      activeRegistration = { owner }
      try {
        return callback()
      } finally {
        window.setTimeout(() => {
          if (activeRegistration?.owner === owner) activeRegistration = null
        }, 10000)
      }
    },
    release(owner) {
      if (activeRegistration?.owner === owner) activeRegistration = null
    },
  }
})()

const props = defineProps(['id', 'title', 'canResize', 'content'])
const isMaximized = ref(false)
const restoredWindowState = ref({
  left: '',
  top: '',
  width: '',
  height: '',
})

const separatorIndex = props.content.indexOf(':')
const contentType = props.content.slice(0, separatorIndex)
const contentValue = props.content.slice(separatorIndex + 1)

const resolvePublicUrl = value => {
  if (/^https?:\/\//.test(value)) return value

  return `${import.meta.env.BASE_URL}${value.replace(/^\/+/, '')}`
}

const applications = useApplicationStore()
const application = computed(() =>
  applications.applications.find(app => app.id === props.id),
)
const isActive = computed(() => applications.getActiveIndex === props.id)
const dosContainer = ref(null)
const dosError = ref('')
let dosInstance = null
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
  if (contentType === 'dos') return

  const windowElement = event.currentTarget.closest('.application-window')
  isMaximized.value = !isMaximized.value

  if (isMaximized.value) {
    const computedStyle = window.getComputedStyle(windowElement)
    restoredWindowState.value = {
      left: windowElement.style.left,
      top: windowElement.style.top,
      width: windowElement.style.width || computedStyle.width,
      height: windowElement.style.height || computedStyle.height,
    }
    windowElement.style.left = '0px'
    windowElement.style.top = '0px'
    windowElement.style.width = ''
    windowElement.style.height = ''
  } else {
    windowElement.style.left = restoredWindowState.value.left
    windowElement.style.top = restoredWindowState.value.top
    windowElement.style.width = restoredWindowState.value.width
    windowElement.style.height = restoredWindowState.value.height
  }
}

const setInitialPosition = () => {
  const windowElement = document.getElementById(props.id)
  const offset = application.value?.windowOffset ?? 0

  if (windowElement) {
    windowElement.style.left = `${offset}rem`
    windowElement.style.top = `${offset}rem`
  }
}

const startDosApplication = async () => {
  if (contentType !== 'dos' || !dosContainer.value) return

  try {
    await nextTick()
    const dosApplicationPath = resolvePublicUrl(
      contentValue.startsWith('/') || contentValue.startsWith('http')
        ? contentValue
        : `applications/${contentValue}`,
    )
    const shadowRoot = dosContainer.value.attachShadow({ mode: 'open' })
    const style = document.createElement('style')
    const playerElement = document.createElement('div')
    style.textContent = jsDosStyles
    playerElement.style.width = '100%'
    playerElement.style.height = '100%'
    shadowRoot.append(style, playerElement)

    const keyboardOwner = () => isActive.value
    dosInstance = dosKeyboardGate.register(keyboardOwner, () =>
      window.Dos(playerElement, {
        url: dosApplicationPath,
        autoStart: true,
        kiosk: true,
        backend: 'dosbox',
        workerThread: false,
        offscreenCanvas: false,
        renderBackend: 'webgl',
        imageRendering: 'pixelated',
        onEvent: event => {
          if (event === 'ci-ready') {
            dosKeyboardGate.release(keyboardOwner)
          }
        },
      }),
    )
    dosInstance.setPaused(!isActive.value)
  } catch (error) {
    dosError.value = 'Unable to start DOS application'
    console.error(error)
  }
}

watch(isActive, active => {
  dosInstance?.setPaused(!active)
})

onMounted(() => {
  setInitialPosition()
  startDosApplication()
})

onUnmounted(() => {
  handlePointerUp()
  dosInstance?.stop?.()
})
</script>

<template>
  <article
    class="application-window"
    :class="{
      'application-window--dos': contentType === 'dos',
      maximized: isMaximized,
    }"
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
        <li v-if="props.canResize && contentType !== 'dos'">
          <button
            class="application-window__button"
            style="font-weight: bolder; line-height: 1.2rem"
            v-on:click.stop="toggleMaximize"
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
        :src="resolvePublicUrl(contentValue)"
        tabindex="0"
        :title="title"
        :style="{ pointerEvents: isActive ? 'auto' : 'none' }"
      ></iframe>
      <div
        v-else-if="contentType === 'dos'"
        ref="dosContainer"
        class="application-window__dos"
        :style="{ pointerEvents: isActive ? 'auto' : 'none' }"
      >
        <span v-if="dosError">{{ dosError }}</span>
      </div>
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

  &--dos {
    width: 59rem;
    height: 40rem;
    resize: none;
  }

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

  &__dos {
    width: 100%;
    height: 100%;
    background-color: $color-black;
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
