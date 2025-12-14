-- 엘,모델의 적합자 보조 장착체
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)

	-----------------------------------------
	-- ① 장착 (ATK +500) (1턴 1번)
	-----------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	-- Equip Limit (기본)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(s.eqlimit)
	c:RegisterEffect(e0)

	-----------------------------------------
	-- ② 효과 복사 (1턴 1번)
	-----------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.cpcon)
	e2:SetCost(s.cpcost)
	e2:SetOperation(s.cpop)
	c:RegisterEffect(e2)

	-----------------------------------------
	-- ③ 공격 시 공격력 2배
	-----------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SET_ATTACK_FINAL)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.atkcon)
	e3:SetTarget(s.atktg)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	-----------------------------------------
	-- ④ 엔드 페이즈 데미지
	-----------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1)
	e4:SetOperation(s.dmgop)
	c:RegisterEffect(e4)
end

------------------------------------------------------------
-- FILTERS
------------------------------------------------------------
-- ① 장착 가능한 대상: "엘,모델의 적합자"(128770189)
function s.eqfilter(c)
	return c:IsFaceup() and c:IsCode(128770189)
end

-- ② 코스트용: 모델(0x759) 몬스터
function s.modelfilter(c)
	return c:IsSetCard(0x759) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end

------------------------------------------------------------
-- ① 장착
------------------------------------------------------------
function s.eqlimit(e,c)
	-- 기본 EquipLimit: 반드시 "엘,모델의 적합자" 또는 엘 퓨전(0x758) 유지
	local tc=e:GetHandler():GetEquipTarget()
	return c==tc or c:IsCode(128770189) or (c:IsType(TYPE_FUSION) and c:IsSetCard(0x758))
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.eqfilter(chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e)) then return end

	-- 장착 (재장착 시 파괴 안됨)
	Duel.Equip(tp,c,tc,true)

	-- ATK +500
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(500)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)

	-- ②가 ①로 장착된 상태에서만 발동 가능하도록 플래그 설정
	c:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
end

------------------------------------------------------------
-- ② 효과 복사
------------------------------------------------------------
function s.cpcon(e)
	local c=e:GetHandler()
	return c:GetEquipTarget()~=nil and c:GetFlagEffect(id)>0  -- 반드시 ① 효과로 장착된 상태
end

function s.cpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.modelfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.modelfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	e:SetLabelObject(g:GetFirst())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject()
	if tc then
		c:CopyEffect(tc:GetOriginalCode(),RESET_EVENT|RESETS_STANDARD)
	end
end

------------------------------------------------------------
-- ③ 공격력 두 배
------------------------------------------------------------
function s.atkcon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and Duel.GetAttacker()==ec
end

function s.atktg(e,c)
	local ec=e:GetHandler():GetEquipTarget()
	return c==ec and (c:IsCode(128770189) or (c:IsType(TYPE_FUSION) and c:IsSetCard(0x758)))
end

function s.atkval(e,c)
	return c:GetAttack()*2
end

------------------------------------------------------------
-- ④ 엔드 페이즈 데미지
------------------------------------------------------------
function s.dmgfilter(c)
	return c:IsFaceup() and (c:IsCode(128770189) or (c:IsType(TYPE_FUSION) and c:IsSetCard(0x758)))
end

function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.dmgfilter,tp,LOCATION_MZONE,0,nil)
	local atk=g:GetSum(Card.GetAttack)
	Duel.Damage(tp,atk,REASON_EFFECT)
end
