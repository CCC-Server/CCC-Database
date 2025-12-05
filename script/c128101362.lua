--오버 리밋 • 사이버 드래곤
local s,id=GetID()

-- ※ 중요: 실제 제작하신 "에볼루션 리절트 버스트"의 카드 번호로 반드시 바꿔주세요.
local CARD_EVOLUTION_RESULT_BURST=12345678 
local CARD_CYBER_DRAGON=70095154

function s.initial_effect(c)
	-- [수정됨] 융합 소환 소재 설정 (Fusion 라이브러리 사용)
	c:EnableReviveLimit()
	-- 소재: "사이버 드래곤" + "오버 리밋" 몬스터 1장
	Fusion.AddProcMix(c,true,true,CARD_CYBER_DRAGON,s.fusfilter)

	-- [추가] 텍스트에 있는 "사이버 드래곤을 제외하고 융합 소재로 할 수 있다" 구현 (컨택트 융합)
	-- (융합 마법 없이 필드의 소재를 제외하고 특수 소환하는 방식)
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit)

	-- ①: 융합 소환 성공 시 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: ATK 3000 이상이면: 몬스터 1장 2회 공격 + 엔드페이즈에 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.multiatk_con)
	e2:SetTarget(s.multiatk_tg)
	e2:SetOperation(s.multiatk_op)
	c:RegisterEffect(e2)

	-- ③: 이 카드 ATK가 원래 공격력의 2배 이상일 때 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.protcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	-- 상대 발동 효과 내성
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.protcon)
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)
end

s.listed_series={0xc48} -- 오버 리밋
s.listed_names={23171610, CARD_EVOLUTION_RESULT_BURST, CARD_CYBER_DRAGON}

-- 융합 소재 필터: "오버 리밋" 몬스터
function s.fusfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0xc48,fc,sumtype,tp) and c:IsType(TYPE_MONSTER)
end

-- [추가] 컨택트 융합 필터 (필드의 사이버 드래곤을 제외)
function s.contactfil(tp)
	return Duel.GetMatchingGroup(Card.IsAbleToRemoveAsCost,tp,LOCATION_ONFIELD,0,nil)
end
function s.contactop(g)
	Duel.Remove(g,POS_FACEUP,REASON_COST+REASON_MATERIAL)
end
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
end

-- ①: 융합 소환된 경우만
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.thfilter(c,code)
	return c:IsCode(code) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,CARD_EVOLUTION_RESULT_BURST)
			or Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,23171610)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.CreateGroup()
	-- 에볼루션 리절트 버스트
	local g1=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,CARD_EVOLUTION_RESULT_BURST)
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg1=g1:Select(tp,1,1,nil)
		g:Merge(sg1)
	end
	-- 리미터 해제
	local g2=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,23171610)
	if #g2>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg2=g2:Select(tp,1,1,nil)
		g:Merge(sg2)
	end
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ②: 공격력 3000 이상 조건
function s.multiatk_con(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetAttack()>=3000
end
function s.multiatk_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER)
end
function s.multiatk_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.multiatk_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.multiatk_filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.multiatk_filter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.multiatk_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- 2회 공격 부여
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		-- 엔드 페이즈 파괴 예약
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_PHASE+PHASE_END)
		e2:SetCountLimit(1)
		e2:SetRange(LOCATION_MZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e2:SetOperation(s.desop)
		e2:SetLabelObject(tc) -- 파괴할 대상을 기억
		Duel.RegisterEffect(e2,tp)
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc and tc:IsLocation(LOCATION_MZONE) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

-- ③: 내성 조건
function s.protcon(e)
	local c=e:GetHandler()
	local atk=c:GetAttack()
	local batk=c:GetBaseAttack()
	if batk<0 then batk=0 end
	return atk>=batk*2
end
function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end