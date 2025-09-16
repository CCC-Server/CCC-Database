--Holophantasy Field – Ensemble (Custom)
local s,id=GetID()
function s.initial_effect(c)
	--Activate (Field Spell)
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--① 자신의 "홀로판타지" 몬스터: ATK = (필드의 "홀로판타지" 몬스터 수) x 400 / 전투로 파괴되지 않음
	-- ATK up
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,tc) return tc:IsSetCard(0xc44) end)
	e1:SetValue(function(e,c) return s.ctfield()*400 end)
	c:RegisterEffect(e1)
	-- Battle indestructible
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_FIELD)
	e1b:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1b:SetRange(LOCATION_FZONE)
	e1b:SetTargetRange(LOCATION_MZONE,0)
	e1b:SetTarget(function(e,tc) return tc:IsSetCard(0xc44) end)
	e1b:SetValue(1)
	c:RegisterEffect(e1b)

	--② GY로 보내졌을 때: 패/덱에서 "홀로판타지" 필드 마법 1장을 필드 존에 놓고,
	--   그 턴 엑스트라에서는 싱크로 몬스터밖에 특수 소환할 수 없음 (하드 OPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- 이 카드명의 ②는 1턴에 1번
	e2:SetTarget(s.fztg)
	e2:SetOperation(s.fzop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc44}

-- === helpers ===
-- 필드(양측)의 앞면 "홀로판타지" 몬스터 수
function s.ctfield()
	return Duel.GetMatchingGroupCount(function(c)
		return c:IsFaceup() and c:IsSetCard(0xc44) and c:IsType(TYPE_MONSTER)
	end,0,LOCATION_MZONE,LOCATION_MZONE,nil)
end

-- ②: 필드 마법 배치 + 엑스트라 싱크로 제한
function s.fspellfilter(c)
	return c:IsSetCard(0xc44) and c:IsType(TYPE_FIELD)
end
function s.fztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	end
	-- MoveToField는 별도의 opinfo 불필요
end
function s.fzop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "필드 마법을 선택"
	local g=Duel.SelectMatchingCard(tp,s.fspellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and not tc:IsForbidden() then
		-- 배치(activate가 아님). 기존 필드마법은 룰에 따라 처리됨.
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	end
	-- 그 턴 Extra는 싱크로만
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
	-- Clock Lizard check (우회 방지)
	aux.addTempLizardCheck(c,tp,function(e,sc) return not sc:IsType(TYPE_SYNCHRO) end)
end
