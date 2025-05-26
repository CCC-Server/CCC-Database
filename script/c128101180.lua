--Ashened Legion Commander
--Scripted by 유희왕 덱 제작기

local s,id=GetID()
-- 🔁 전역 화염족 효과 추적 변수
if not s.global_check then
   s.global_check = true
   s.pyro_activated_this_turn = {[0]=false,[1]=false}

   -- 🔥 화염족 효과 발동 시 체크
   local ge1=Effect.GlobalEffect()
   ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
   ge1:SetCode(EVENT_CHAINING)
   ge1:SetOperation(function(_,_,_,_,_,re,_,rp)
      local rc = re:GetHandler()
      if rc:IsRace(RACE_PYRO) and rc:IsType(TYPE_MONSTER) then
         s.pyro_activated_this_turn[rp] = true
      end
   end)
   Duel.RegisterEffect(ge1,0)

   -- 턴 시작 시 리셋
   local ge2=Effect.GlobalEffect()
   ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
   ge2:SetCode(EVENT_PHASE_START+PHASE_DRAW)
   ge2:SetOperation(function()
      s.pyro_activated_this_turn[0] = false
      s.pyro_activated_this_turn[1] = false
   end)
   Duel.RegisterEffect(ge2,0)
end

function s.initial_effect(c)
   --① 메인페이즈 중 프리체인 특수 소환
   local e1=Effect.CreateEffect(c)
   e1:SetDescription(aux.Stringid(id,0))
   e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
   e1:SetType(EFFECT_TYPE_QUICK_O)
   e1:SetCode(EVENT_FREE_CHAIN)
   e1:SetRange(LOCATION_HAND)
   e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
   e1:SetCountLimit(1,id)
   e1:SetCondition(s.spcon)
   e1:SetTarget(s.sptg)
   e1:SetOperation(s.spop)
   c:RegisterEffect(e1)

   --② 소환 성공 시 회멸 몬스터 서치 (선택 발동)
   local e2=Effect.CreateEffect(c)
   e2:SetDescription(aux.Stringid(id,1))
   e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
   e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O) -- 옵션 발동
   e2:SetCode(EVENT_SUMMON_SUCCESS)
   e2:SetCountLimit(1,{id,1})
   e2:SetTarget(s.thtg)
   e2:SetOperation(s.thop)
   c:RegisterEffect(e2)
   local e2b=e2:Clone()
   e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
   c:RegisterEffect(e2b)

   --③ 특수 소환된 턴 동안 상대 필드 몬스터는 화염족
   local e3=Effect.CreateEffect(c)
   e3:SetType(EFFECT_TYPE_FIELD)
   e3:SetCode(EFFECT_CHANGE_RACE)
   e3:SetRange(LOCATION_MZONE)
   e3:SetTargetRange(0,LOCATION_MZONE)
   e3:SetValue(RACE_PYRO)
   e3:SetCondition(s.racecon)
   c:RegisterEffect(e3)
end

--------------------------------------------------
--① 조건: 메인 페이즈 + 화염족 효과 발동 이력
--------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
   return Duel.IsMainPhase() and s.pyro_activated_this_turn[tp]
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
   if chk==0 then
      return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
         and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
   end
   Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
   local c=e:GetHandler()
   if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
   if c:IsRelateToEffect(e) then
      Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP)
      Duel.SpecialSummonComplete()
   end
end

--------------------------------------------------
--② 서치: 회멸 몬스터 1장 (자신 제외)
--------------------------------------------------
function s.thfilter(c)
   return c:IsSetCard(SET_ASHENED) and not c:IsCode(id)
      and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
   if chk==0 then
      return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
   end
   Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
   local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
   if #g>0 then
      Duel.SendtoHand(g,nil,REASON_EFFECT)
      Duel.ConfirmCards(1-tp,g)
   end
end

--------------------------------------------------
--③ 지속 효과: 특소된 턴 동안 상대 필드 몬스터는 화염족
--------------------------------------------------
function s.racecon(e)
   local c=e:GetHandler()
   return c:IsSummonType(SUMMON_TYPE_SPECIAL)
      and Duel.GetTurnCount() == c:GetTurnID()
end
