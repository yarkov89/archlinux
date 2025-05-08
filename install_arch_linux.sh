#!/bin/bash

# Arch Linux Install - Быстрая установка Arch Linux
# Цель скрипта - быстрое развертывание системы с персональными настройками (конфиг KDE, программы и т.д.).

# Основные переменные


echo ========== УСТАНОВКА ARCH LINUX ==========

loadkeys ru
setfont cyr-sun16

echo 'Скрипт сделан на основе собственной инструкции по Установке ArchLinux'

echo '1.3 Синхронизация системных часов'
timedatectl set-ntp true

echo '2.1 Создание разделов'
echo 'Для управления разделами на жестком диске в процессе установки используется программа fdisk.'

#/dev/sda1 - 100M EFI
#/dev/sda2 - 30G root Linux File System
#/dev/sda3 - Весь остаток home Linux file System


(
  echo g;

  echo n;
  echo;
  echo;
  echo +512M;

  echo n;
  echo;
  echo;
  echo;

  echo w;
) | fdisk /dev/sda

(
#Ставим тип файловой систмы EFI
  echo t;
  echo 1;
  echo 1;

  #Ставим тип файловой систмы root
  echo t;
  echo 2;
  echo 23;

  echo w;
) | fdisk /dev/sda


echo 'Ваша разметка диска'
fdisk -l

echo '2.4.2 Форматирование дисков'
mkfs.fat -F 32  /dev/sda1
mkfs.ext4  /dev/sda2 -L root
#mkswap /dev/sda3 -L swap
#mkfs.ext4  /dev/sda4 -L home


echo '2.4.3 Монтирование дисков'
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

#mkdir /mnt/{boot,home}
#mount /dev/sda1 /mnt/boot
#swapon /dev/sda3
#mount /dev/sda4 /mnt/home

echo '3.1 Выбор зеркал для загрузки. Ставим зеркало от Яндекс'
echo "Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

echo '3.2 Установка основных пакетов'
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware refind dhcpcd nano intel-ucode

echo '3.3 Настройка системы'
genfstab -pU /mnt >> /mnt/etc/fstab

#echo 'Заходим в систему'
#arch-chroot /mnt

read -p "Введите имя компьютера: " hostname
read -p "Введите имя пользователя: " username

echo 'Прописываем имя компьютера'
echo $hostname > /mnt/etc/hostname
ln -svf usr/share/zoneinfo/Europe/Moscow /mnt/etc/localtime

echo '3.4 Добавляем русскую локаль системы'
echo "ru_RU.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen

echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' > /mnt/etc/locale.conf

echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
echo 'KEYMAP=ru' >> /mnt/etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /mnt/etc/vconsole.conf

echo 'Создадим загрузочный RAM диск'
echo -n "" > /mnt/etc/mkinitcpio.conf
echo 'MODULES=(i915)' >> /mnt/etc/mkinitcpio.conf
echo 'BINARIES=()' >> /mnt/etc/mkinitcpio.conf
echo 'FILES=()' >> /mnt/etc/mkinitcpio.conf
echo 'HOOKS=(base udev autodetect modconf block filesystems keyboard keymap)' >> /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /usr/bin/mkinitcpio -P linux-zen
#mkinitcpio -p linux

echo '3.5 Устанавливаем загрузчик'
#pacman -Syy
#pacman -S grub --noconfirm
#grub-install /dev/sda

echo 'Обновим текущую локаль системы'
arch-chroot /mnt /usr/bin/locale-gen

echo 'Устанвливаем refind'
#refind-install --usedefault /dev/sda1
arch-chroot /mnt /usr/bin/refind-install --usedefault /dev/sda1

echo 'Добавляем пользователя: ' $username
#useradd -m -g users -G wheel -s /bin/bash $username
arch-chroot /mnt /usr/bin/useradd -m -g users -G wheel -s /bin/bash $username

echo 'Создаем root пароль'

arch-chroot /mnt /usr/bin/passwd
#passwd

echo 'Устанавливаем пароль пользователя: ' $username
#passwd $username
arch-chroot /mnt /usr/bin/passwd $username



#echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
#echo '[multilib]' >> /mnt/etc/pacman.conf
#echo 'Include = /etc/pacman.d/mirrorlist' >> /mnt/etc/pacman.conf
#pacman -Syy

echo "Куда устанавливем Arch Linux на виртуальную машину?"
read -p "1 - Да, 0 - Нет: " vm_setting
if [[ $vm_setting == 0 ]]; then
  gui_install="xorg xorg-server xorg-xinit"
elif [[ $vm_setting == 1 ]]; then
  gui_install="xorg xorg-server xorg-xinit virtualbox-guest-utils xf86-video-vesa"
fi

echo 'Ставим иксы и драйвера'
arch-chroot /mnt /usr/bin/pacman -S $gui_install

echo "Настраиваем звук"
arch-chroot /mnt /usr/bin/pacman -S pulseaudio pulseaudio-alsa pavucontrol alsa-lib alsa-utils

echo 'KDE-Plasma + SDDM + Интернет'
arch-chroot /mnt /usr/bin/pacman -S plasma-desktop sddm plasma-nm


echo 'Cтавим программы'
arch-chroot /mnt /usr/bin/pacman -S plasma-nm konsole dolphin plasma-pa kate mc
#arch-chroot /mnt /usr/bin/pacman -S plasma-nm konsole kate okular gimp vlc git telegram-desktop dolphin kcalc spectacle keepassxc ark plasma-systemmonitor sddm-kcm libreoffice-fresh libreoffice-fresh-ru ntfs-3g gwenview ffmpegthumbs kdegraphics-thumbnailers kimageformats qt5-imageformats taglib unrar plasma-pa ktorrent

echo 'Ставим шрифты'
#pacman -S ttf-liberation ttf-dejavu --noconfirm

echo 'Ставим сеть'
#pacman -S networkmanager network-manager-applet ppp --noconfirm

echo 'Подключаем автозагрузку менеджера входа и интернет'
arch-chroot /mnt /usr/bin/systemctl enable sddm
arch-chroot /mnt /usr/bin/systemctl enable NetworkManager
#systemctl enable NetworkManager
#systemctl enable dhcpcd.service

echo 'Устанавливаем SUDO'
#echo '%wheel ALL=(ALL) ALL' >> /mmt/etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

exit
umount /mnt/boot
umount /mnt
echo 'Установка завершена! Перезагрузите систему.'
