--Holophantasy Field (Custom)
local s,id=GetID()
function s.initial_effect(c)
  -- Activate (일반 필드마법 발동)
  local e0=Effect.CreateEffect(c)
  e0:SetDescription(aux.Stringid(id,0))
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)

  -- ① 이 카드가 필드에 존재하는 한, 상대는 자신 필드의 "홀로판타지" 몬스터를 효과의 대상으로 할 수 없다.
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)   -- 내 몬스터가 내성이라도 적용되도록
  e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
  e1:SetRange(LOCATION_FZONE)
  e1:SetTargetRange(LOCATION_MZONE,0)
  e1:SetTarget(function(e,tc) return tc:IsSetCard(0xc44) end)
  e1:SetValue(aux.tgoval)  -- 상대의 효과만 대상 지정 불가로 만듦
  c:RegisterEffect(e1)

  -- ② GY로 보내졌을 때: 패/덱에서 "홀로판타지" 필드마법 1장을 필드존에 놓음 → 그 턴 Extra는 싱크로만
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetProperty(EFFECT_FLAG_DELAY)
  e2:SetCode(EVENT_TO_GRAVE)
  e2:SetCountLimit(1,{id,1})   -- "이 카드명의 ②의 효과는 1턴에 1번"
  e2:SetTarget(s.fztg)
  e2:SetOperation(s.fzop)
  c:RegisterEffect(e2)
end
s.listed_series={0xc44}

-- 선택 가능한 "홀로판타지" 필드 마법
function s.fspellfilter(c)
  return c:IsSetCard(0xc44) and c:IsType(TYPE_FIELD)
end

-- ② 타깃/준비: 패/덱에 놓을 필드 마법이 있는지 확인
function s.fztg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
	return Duel.IsExistingMatchingCard(s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
  end
  -- MoveToField에는 별도 OperationInfo가 필요 없음
end

-- ② 처리: 필드 마법 배치 → 그 턴 Extra는 싱크로만 특소 가능
function s.fzop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "필드 마법을 선택"
  local g=Duel.SelectMatchingCard(tp,s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
  local tc=g:GetFirst()
  if tc and not tc:IsForbidden() then
	-- 필드존에 '놓기'(activate 아님). 기존 필드가 있으면 룰에 따라 처리됨.
	Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
  end

  -- 그 턴, Extra에서 싱크로 이외 특소 불가 (표시/클라이언트 힌트 포함)
  local c=e:GetHandler()
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,3)) -- "이 턴, 엑스트라 덱에서 싱크로 이외는 특수 소환할 수 없다."
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
  e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
  e1:SetTargetRange(1,0)
  e1:SetTarget(function(e,sc) return sc:IsLocation(LOCATION_EXTRA) and not sc:IsType(TYPE_SYNCHRO) end)
  e1:SetReset(RESET_PHASE|PHASE_END)
  Duel.RegisterEffect(e1,tp)

  -- Clock Lizard 체크 (엑스트라 제한을 회피하는 효과 방지)
  aux.addTempLizardCheck(c,tp,function(e,sc) return not sc:IsType(TYPE_SYNCHRO) end)
end
