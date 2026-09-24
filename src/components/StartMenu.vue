<script setup>
import BookIcon from '../assets/images/book.png'
import ProgramsIcon from '../assets/images/programs.png'
import ShutdownIcon from '../assets/images/shutdown.png'
import SnakeIcon from '../assets/images/snake.png'
import PokerIcon from '../assets/images/poker.png'
import HackmanIcon from '../assets/images/hackman.png'
import { useApplicationStore } from '@/stores/applications'

const props = defineProps({
  visible: Boolean,
})

const emit = defineEmits(['close'])
const applications = useApplicationStore()

const openApplication = (title, path) => {
  applications.pushApplication(title, `website:${path}`)
  emit('close')
}

const openDosApplication = (title, filename) => {
  applications.pushApplication(title, `dos:${filename}`)
  emit('close')
}
</script>

<template>
  <aside v-if="props.visible" class="start-menu" @click.stop>
    <div class="start-menu__stripe">
      <span>Quintin Herb</span>
    </div>
    <div class="start-menu__content">
      <div class="start-menu__item start-menu__item--programs">
        <img :src="ProgramsIcon" alt="" class="start-menu__icon" />
        <span>Programs</span>
        <span class="start-menu__caret">&#9654;</span>
        <div class="start-menu__flyout">
          <button
            class="start-menu__flyout-item"
            type="button"
            @click="
              openApplication('Checkbox Snake', 'applications/snake.html')
            "
          >
            <img :src="SnakeIcon" alt="" />
            <span>Checkbox Snake</span>
          </button>
          <button
            class="start-menu__flyout-item"
            type="button"
            @click="openDosApplication('Hackman', 'HACKMAN.jsdos')"
          >
            <img :src="HackmanIcon" alt="" />
            <span>Hackman</span>
          </button>
          <button
            class="start-menu__flyout-item"
            type="button"
            @click="openDosApplication('Video Poker', 'VPOKER.jsdos')"
          >
            <img :src="PokerIcon" alt="" />
            <span>Video Poker</span>
          </button>
        </div>
      </div>
      <button
        class="start-menu__item"
        type="button"
        @click="openApplication('About Me', 'applications/about-me.html')"
      >
        <img :src="BookIcon" alt="" class="start-menu__icon" />
        <span>About Me</span>
      </button>
      <div class="start-menu__divider"></div>
      <a class="start-menu__item" href="https://quintinherb.net">
        <img :src="ShutdownIcon" alt="" class="start-menu__icon" />
        <span>Shut Down</span>
      </a>
    </div>
  </aside>
</template>

<style lang="scss">
.start-menu {
  position: fixed;
  left: 0;
  bottom: 4.2rem;
  z-index: 10001;
  display: flex;
  width: 25rem;
  height: 15.8rem;
  box-sizing: content-box;
  background-color: $color-gray;
  border-top: 3px solid $color-gray;
  border-left: 3px solid $color-gray;
  border-right: 2px solid $color-gray-dark;
  border-bottom: 2px solid $color-gray-dark;
  box-shadow: 1px 1px 0 1px $color-black;
  user-select: none;

  &__stripe {
    position: relative;
    width: 3rem;
    flex: 0 0 3rem;
    background-color: $color-gray-dark;
    color: $color-white;
    overflow: hidden;

    span {
      position: absolute;
      bottom: -1.4rem;
      left: 0.4rem;
      transform: rotate(-90deg);
      transform-origin: left top;
      white-space: nowrap;
      font-size: 2.133rem;
      letter-spacing: 0.2rem;
    }
  }

  &__content {
    flex: 1;
    width: 22rem;
    padding: 0;
  }

  &__item {
    position: relative;
    display: flex;
    align-items: center;
    width: 100%;
    height: 5rem;
    padding: 0;
    border: 0;
    background: transparent;
    color: $color-black;
    font: inherit;
    font-size: 1.6rem;
    text-align: left;
    text-decoration: none;
    cursor: pointer;

    &:hover {
      background-color: $color-blue;
      color: $color-white;
    }
  }

  &__icon {
    width: 4rem;
    height: 4rem;
    object-fit: contain;
    margin: 0.5rem 1rem;
  }

  &__caret {
    margin-left: auto;
    margin-right: 1rem;
    font-size: 1.33rem;
  }

  &__divider {
    height: 0.4rem;
    margin: 0;
    background-color: $color-gray-dark;
    border-bottom: 0.2rem solid $color-white;
  }

  &__flyout {
    position: absolute;
    top: 0;
    left: 100%;
    display: none;
    width: 22rem;
    padding: 0;
    box-sizing: content-box;
    background-color: $color-gray;
    border-top: 3px solid $color-gray;
    border-left: 3px solid $color-gray;
    border-right: 2px solid $color-gray-dark;
    border-bottom: 2px solid $color-gray-dark;
    box-shadow: 1px 1px 0 1px $color-black;
  }

  &__item--programs:hover &__flyout {
    display: block;
  }

  &__flyout-item {
    display: flex;
    align-items: center;
    height: 3.2rem;
    padding: 0 0.4rem;
    width: 100%;
    border: 0;
    background: transparent;
    color: $color-black;
    text-align: left;
    cursor: pointer;
    font-size: 1.6rem;

    &:hover {
      background-color: $color-blue;
      color: $color-white;
    }

    img {
      width: 2.4rem;
      height: 2.4rem;
      object-fit: contain;
      margin-right: 0.4rem;
    }
  }
}
</style>
