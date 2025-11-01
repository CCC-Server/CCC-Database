--Junk Destruction Boost (가칭)
local s,id=GetID()
local CARD_JUNK_WARRIOR=60800381

function s.initial_effect(c)
	-- ①: 발동만 함 (효과 없음, 이후 Quick Effect로 별도 발동)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ②: Quick Effect - 필드의 카드 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_SZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- ③: 전투 데미지 배가
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.damtarget)
	e2:SetCondition(s.damcon)
	e2:SetValue(aux.ChangeBattleDamage(1,DOUBLE_DAMAGE))
	c:RegisterEffect(e2)
end

s.listed_names={CARD_JUNK_WARRIOR}
s.listed_series={0x43} -- "정크" 시리즈

---------------------------------------------------------------
-- ②: 필드 카드 파괴 효과
---------------------------------------------------------------
function s.synfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevelAbove(8)
end
function s.junksynfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x43)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local exc=not c:IsStatus(STATUS_EFFECT_ENABLED) and c or nil
	if chkc then return chkc:IsOnField() and chkc:IsFaceup() and (not exc or chkc~=exc) end

	local ct=1
	if Duel.IsExistingMatchingCard(s.junksynfilter,tp,LOCATION_MZONE,0,1,nil) then
		ct=2
	end

	if chk==0 then
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,exc)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,exc)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg>0 then
		Duel.Destroy(tg,REASON_EFFECT)
	end
end

---------------------------------------------------------------
-- ③: 전투 데미지 배가
---------------------------------------------------------------
function s.damtarget(e,c)
	return (c:IsCode(CARD_JUNK_WARRIOR) or (c:IsType(TYPE_SYNCHRO) and c:IsLevelAbove(8)))
		and c:IsControler(e:GetHandlerPlayer())
end

function s.damcon(e)
	-- 데미지 스텝 or 상대 턴에만 적용
	return Duel.GetTurnPlayer()~=e:GetHandlerPlayer() or Duel.GetCurrentPhase()==PHASE_DAMAGE
end
